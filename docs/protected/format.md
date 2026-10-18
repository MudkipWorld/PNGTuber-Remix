# Protected container v1

Target: PNGTuber-Remix 1.4.5. All integers little endian.

| Field | Bytes |
|---|---:|
| ASCII PNGRMP01 | 8 |
| Container version = 1 | u32 |
| Target version length = 5 | u32 |
| UTF-8 1.4.5 | 5 |
| Key identifier | 16 |
| Random IV | 16 |
| Ciphertext length | u64 |
| AES-256-CBC ciphertext, PKCS#7 padding | variable |
| HMAC-SHA256(header + ciphertext), independent key | 32 |

Maximum container size: 512 MiB. Header, version, lengths, exact EOF and HMAC are validated before decryption. The payload uses Godot's non-object Variant serialization. Whitelisted InputEvent types are encoded as field dictionaries and reconstructed explicitly; arbitrary objects are rejected. Integer-valued float sprite IDs are preserved because upstream declares them as float.

PNG images are checked before scene replacement. Current schema limits each PNG to 16384 pixels per side and 64 megapixels. These are resource limits, not changes to motion data.

Two random 32-byte keys and a 16-byte key ID are generated locally in `Protected/generated/BuildKeys.gd`, ignored by Git. The same key file must be used for both builds. It must be backed up privately by the creator. Runtime key material is necessarily present in the offline program; this is not a DRM guarantee against reverse engineering.

Build: run `tools/build-protected.ps1 -Role creator` and `-Role player` with Godot 4.6 and official Windows export templates. Templates are selected by absolute path beside the Godot executable. Test: `tools/test-protected.ps1`.
