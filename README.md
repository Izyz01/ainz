# All I Need Z

Run the online loader in your compatible executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Izyz01/ainz/main/loader.luau"))()
```

Enter the access key you received from the owner. The loader downloads the AINZ scripts and icons and opens the UI for your supported game (Natural Disaster Survival or Flee the Facility).

Required executor support: HTTP requests with headers, file reading/writing, folders, loadstring, custom image assets, and the existing AINZ runtime APIs. Madium MCP is not required to download the release.

Only the loader is public. Release payloads are hosted privately and served after key validation. Keys are retained in session memory, not written to a preferences file. Do not share your key. Revocation blocks future downloads; it cannot remove previously downloaded copies.

Each key can be redeemed by one Roblox account. It binds to the first UserId reported by the loader; that account can reuse it until expiry or revocation. Another account receives an already-redeemed message. This automatic binding prevents casual sharing but is not verified Roblox ownership; modified clients can spoof a UserId.

The release host limits requests per IP to 60/minute and failed key checks to 10/minute. HTTP 429 means wait one minute before retrying. Shared networks share the allowance; native limits are approximate per Cloudflare location.
