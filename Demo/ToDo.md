1. Create Habitats * 5
    - URL = GeoLocations
    - Using NFTPort
    - Use special implementation (later)
        Special implementation will allow aggregation with Egg

2. Create Assets:
    - URL = small graphic on a different background.
    - One for each Protection asset
    - One for each Recovery asset
    - Using NFTPort
    - Special implementation (later)
        Special implementation of Recovery assets allows burn and re-mint on aggregation by DAO
        Special implementation of Protection assets allows aggregation by DAO
        Special implementataion allows AlwaysOnSale?

3. Create Kiwis:
    - URL is updatable (how)
    - Initially just a generic egg image with a date and number overlay
        Metadata = Recovery date, location, parents
    - Then becomes an egg with a picture of 1 say old Kiwi with link to egg.
        Metadata += hatch date, incubation centre
    - Then becomes a release video with a link to picture. 
        Metadata += release date, release location (as a URL)

4. Create a DAO
    - Only allows distribution of funds to token holders
        distribute() - Called by Gelato timer? or any holder or NGO.
        registerNGO()  
    - Allows funding of a project.
        proposProject(), vote()
    - Used to convert Assets into Eggs.
        function MintEgg(asset[]), burn(assets[])
    - collects royalties 
        2981 resales
        initial purchase prices (auction)
        
