param(
    [string]$SourceRoot = "$PSScriptRoot/../../Faust-local-source/_unpack",
    [string]$OutputPath = "$PSScriptRoot/../../Faust-artifacts/ban-word-oracle.json"
)
$ErrorActionPreference = 'Stop'
# Independent .NET AES/PBKDF2/Regex execution of the original source chain.
# Does not start the original executable, modify its files, or access network.
Add-Type -TypeDefinition @'
using System;
using System.Security.Cryptography;
#pragma warning disable SYSLIB0041, SYSLIB0060
public static class SourceBanWordOracle {
    static ulong Rotate(ulong value, int bits) { return (value << bits) | (value >> (64-bits)); }
    static byte[] Password(ulong[] s) {
        var output = new byte[32];
        unchecked { for (int i=0;i<32;i++) {
            ulong old=s[1]; s[2]^=s[0]; s[3]^=s[1]; s[1]^=s[2]; s[0]^=s[3];
            s[2]^=old<<17; s[3]=Rotate(s[3],45);
            output[i]=(byte)((Rotate(old*5,7)*9)>>((i*4)&63));
        }} return output;
    }
    public static long DeriveCardSeed(int mask) {
        var random=new Random(mask);
        unchecked {
            uint x=(uint)random.Next(), y=1812433253*x+1, z=1812433253*y+1, w=1812433253*z+1;
            uint t=x^(x<<11); w=w^(w>>19)^t^(t>>8);
            int sample=(int)((long)w-2147483648L);
            return (long)random.Next()*sample;
        }
    }
    public static byte[] Decrypt(byte[] blob, ulong rite, long card) {
        const ulong b=0x60dfa3185012834b, c=0x4fd28231cae9901c;
        ulong d=unchecked((ulong)card);
        using (var kdf=new Rfc2898DeriveBytes(Password(new[]{d,b,rite,c}),Password(new[]{b,d,c,rite}),1000))
        using (var aes=Aes.Create()) {
            aes.Mode=CipherMode.CBC; aes.Padding=PaddingMode.PKCS7;
            var iv=new byte[16]; Array.Copy(blob,iv,16);
            using(var transform=aes.CreateDecryptor(kdf.GetBytes(32),iv))
                return transform.TransformFinalBlock(blob,16,blob.Length-16);
        }
    }
}
'@
$scene = Get-Content -LiteralPath "$SourceRoot/unity_export/ExportedProject/Assets/Scenes/InitScene.unity" -Raw -Encoding UTF8
$blocks = [regex]::Split($scene, '(?m)^--- ')
$creator = $blocks | Where-Object { $_.Contains('PackerSeed:') } | Select-Object -First 1
$gameObject = [regex]::Match($creator, 'm_GameObject: \{fileID: (\d+)\}').Groups[1].Value
$camera = $blocks | Where-Object { $_.StartsWith('!u!20 ') -and $_.Contains("m_GameObject: {fileID: $gameObject}") } | Select-Object -First 1
$mask = [int][regex]::Match($camera, 'm_Bits: (\d+)').Groups[1].Value
$riteSeed = [ulong][regex]::Match($creator, 'PackerSeed: (\d+)').Groups[1].Value
$cardSeed = [SourceBanWordOracle]::DeriveCardSeed($mask)
$sourceFile = [IO.Path]::GetFullPath("$SourceRoot/unity_export/ExportedProject/Assets/Resources/ban_words.bytes")
$decoded = [SourceBanWordOracle]::Decrypt([IO.File]::ReadAllBytes($sourceFile), $riteSeed, $cardSeed)
$plainHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($decoded)).ToLowerInvariant()
if ($plainHash -ne 'a4969c5a3e07c4fc690ef588c3509d3c4f69a39283f7a59e17589b63e512074a') { throw 'Unexpected original plaintext' }
$sourceWords = @([Text.Encoding]::UTF8.GetString($decoded) | ConvertFrom-Json)
$words = @($sourceWords | ForEach-Object { $_.Trim().ToLower() } | Select-Object -Unique)
$literals = Get-Content -LiteralPath "$SourceRoot/il2cpp_dump/stringliteral.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$skipChars = ($literals | Where-Object { $_.address -eq '0x25AC008' }).value
$skip = [regex]::new('[' + $skipChars + ']')
$normalWords = @($words | Where-Object { -not $skip.IsMatch($_) } | ForEach-Object { [regex]::Escape($_) } | Sort-Object Length -Descending)
$normal = [regex]::new(($normalWords -join '|'))
$specialWords = @($words | Where-Object { $skip.IsMatch($_) } | Where-Object { $stripped=$skip.Replace($_,''); $stripped.Length -eq 0 -or $normal.Replace($stripped,'').Length -ne 0 } | ForEach-Object { [regex]::Escape($_) } | Sort-Object Length -Descending)
$special = if ($specialWords.Count) { [regex]::new(($specialWords -join '|')) } else { $null }
$names = [Collections.Generic.List[string]]::new()
foreach ($word in $words) {
    $names.Add($word); $names.Add($word.ToUpper()); $names.Add('a'+$word+'b')
    foreach ($separator in @(' ', '_', 'α', '.', '/', '，', '0', '中', [string][char]0x00a0, [string][char]0x200b)) {
        $names.Add(($word.ToCharArray() -join $separator))
    }
    for ($i=0; $i -lt $word.Length; $i++) { $names.Add($word.Remove($i,1)) }
}
foreach ($name in @('', '阿尔图', '新名字', '玩家', 'Alice', '普通学生', '                  ')) { $names.Add($name) }
$cases = @($names | Select-Object -Unique | ForEach-Object {
    $lower=$_.ToLower()
    $blocked=($null -ne $special -and $special.IsMatch($lower)) -or $normal.IsMatch($skip.Replace($lower,''))
    @{input=$_; blocked=$blocked; valid=($_.Length -ge 1 -and $_.Length -le 20 -and -not $blocked)}
})
$result = [ordered]@{source=$sourceFile; encrypted_sha256=(Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash.ToLowerInvariant(); plaintext_sha256=$plainHash; camera_mask=$mask; card_seed=$cardSeed; word_count=$sourceWords.Count; unique_word_count=$words.Count; normal_count=$normalWords.Count; special_count=$specialWords.Count; cases=$cases; boundary='Offline original-source .NET oracle; not original executable mouse acceptance'}
$json = $result | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $json, [Text.UTF8Encoding]::new($false))
Write-Output "Original-source oracle: $($words.Count) words, $($cases.Count) cases, plaintext SHA256 $plainHash"
