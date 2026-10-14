# All I Need Z

Run the online loader in your compatible executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Izyz01/ainz/main/loader.luau"))()
```

Enter the access key you received from the owner. The loader downloads the AINZ scripts and icons and opens the UI for your supported game (Natural Disaster Survival or Flee the Facility).

Required executor support: HTTP requests with headers, file reading/writing, folders, loadstring, custom image assets, and the existing AINZ runtime APIs. Madium MCP is not required to download the release.

Only the loader is public. Release payloads are hosted privately and served after key validation. Keys are retained in session memory, not written to a preferences file. Do not share your key. Revocation blocks future downloads; it cannot remove previously downloaded copies.
