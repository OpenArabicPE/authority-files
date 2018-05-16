[GeoNames.org](https://www.geonames.org) provides an API that allows to query for toponyms. It returns XML, which provides names in various languages, coordinates etc. Details of the search api can be found here <http://www.geonames.org/export/geonames-search.html> and thers is also a [demo](http://api.geonames.org/search?name=Cairo&username=demo).

- also working: <http://api.geonames.org/search?name=%D8%A7%D9%84%D9%82%D9%8A%D9%85%D8%B1%D9%8A%D8%A9&username=demo> this represents the arabic word القيمرية
    
- further APIs are the `contains?` and `nearby?` APIs, which allow, for instance, to query for all Mosques in within a given radius
    - <http://api.geonames.org/contains?geonameId=170654&username=tardigradae>
    - <http://api.geonames.org/findNearby?lat=33.5102&lng=36.29128&radius=3.3&featureClass=S&featureCode=MSQE&style=FULL&maxRows=100&username=tardigradae>
- if one wants to retrieve information for a known geonameId, use `get?`: <http://api.geonames.org/get?geonameId=170654&radius=3.3&style=FULL&username=tardigradae>