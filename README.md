# get-best-dns.sh

A simple Bash script to test DNS server responsiveness and find the fastest ones. It supports a default DNS list from a file, additional DNS servers via command-line, and custom domains.

## Features

- Test DNS servers from a file (`dns-list`) or add extra servers via command-line.
- Default query domain is `openai.com`, but you can specify any domain.
- Measures response time for each DNS server.
- Displays top 3 fastest DNS servers based on response time.
- Only IPv4 DNS servers supported.

## Requirements

- Bash
- `dig` command (part of `dnsutils` on Ubuntu/Debian)

## Usage

./get-best-dns.sh [options]

### Options

- `-d [domain]` : Specify the domain to query (default: `openai.com`)
- `-a [dns...]` : Additional extra DNS server(s) to test

### Examples

1. Use default domain (`openai.com`) and DNS servers from `dns-list`:
   ./get-best-dns.sh

2. Test a different domain:
   ./get-best-dns.sh -d example.com

3. Add extra DNS servers:
   ./get-best-dns.sh -l 115.178.58.26 198.101.242.72

4. Specify domain and add extra DNS servers at the same time:
   ./get-best-dns.sh -d example.com -l 115.178.58.26 198.101.242.72

## Output

- `[OK] <DNS> → <IP> (<response time> ms)` for successful queries.
- `[FAIL] <DNS> did not respond` for servers that did not reply.
- At the end, shows top 3 fastest DNS servers based on response time.

Example:
✅ Top 3 fastest DNS:
8.8.8.8 (34 ms)
1.1.1.1 (36 ms)
9.9.9.9 (40 ms)

## Warnings for heavy DNS testing

Testing many DNS servers repeatedly or frequently may cause the DNS servers to block or limit your requests.

To avoid issues:

1. **Add delays between tests**
   - Do not run the script hundreds of times consecutively
   - Add 1–2 seconds delay between queries

2. **Rotate domain names**
   - To prevent being flagged as an attack, use random test domains such as `test-<timestamp>.example.com`

3. **Limit the number of DNS servers per run**
   - Recommended to test no more than 20–30 DNS servers at a time

4. **Use your own DNS if possible**
   - If frequent testing is needed, use internal or controlled DNS servers

## Notes

- The script primarily supports IPv4
- DNS servers that do not respond are marked as `[FAIL]`
- The top 3 fastest DNS servers are sorted by average response time
- Default DNS servers are read from the `dns-list` file; add extra servers with `-a`.
- Uses `dig` with `+time=2 +tries=1` to minimize waiting on slow or unresponsive servers.

## License

MIT License