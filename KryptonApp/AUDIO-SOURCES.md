# Recording expansion candidates

These recordings are not installed in the app. Their public Freesound pages were checked on September 24, 2026 and list CC0. Requests for the pages from the local download tools returned HTTP 403; the browser tool also blocked the page, and the user reported a blank page. Openverse search was reachable and exposed public preview URLs, but a direct preview download also returned HTTP 403. Only successfully downloaded and verified audio should be added to `resources/animals.json`.

| Category | Recording | Creator | Source duration | Source |
| --- | --- | --- | --- | --- |
| Chirps | Squirrel Chirping (Montreal public park) | eclectic-kitty | 20.248 seconds | https://freesound.org/people/eclectic-kitty/sounds/757642/ |
| Barks | Barking Squirrel in the City (Los Angeles) | RavenWolfProds | 123.608 seconds | https://freesound.org/people/RavenWolfProds/sounds/622061/ |
| Eating | 180524 Squirrel, chewing scratching eating TORONTO.flac | TRP | 61.494 seconds | https://freesound.org/people/TRP/sounds/570988/ |

Reuse terms: https://creativecommons.org/publicdomain/zero/1.0/

Species are not established by these sources; retain that uncertainty. The Los Angeles recordist describes defensive behavior, but that is the recordist's interpretation. Use an audible-description category such as Barks. The eating recording also contains scratching.

For integration: obtain the original via the source's normal download flow (login may be required) or its public preview, retain the source and download URL, measure duration and levels, document any changes, generate a SHA-256 checksum, and exercise it in the simulator. The catalog's `category` field creates a section automatically. Do not add missing-file placeholders to the playable catalog.
