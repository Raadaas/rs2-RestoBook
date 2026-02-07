using eCommerce.Model;
using eCommerce.Services.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;

namespace eCommerce.WebAPI.Controllers;

/// <summary>
/// Pokretanje data seeda preko Swaggera: POST /api/seed. Dodaje gradove (BiH), tipove kuhinje, admina, klijenta, 5 restorana i nagrade (rewards). Samo ako su tablice prazne.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class SeedController : ControllerBase
{
    private const int SaltSize = 16;
    private const int KeySize = 32;
    private const int Iterations = 10000;
    private const string AdminPassword = "Admin123!";
    private const string ClientPassword = "Klijent123!";

    private readonly eCommerceDbContext _db;

    public SeedController(eCommerceDbContext db)
    {
        _db = db;
    }

    /// <summary>
    /// Pokreće seed: gradovi (BiH), tipovi kuhinje (bosansko-srpski), admin (vlasnik), klijent, 5 restorana s stolovima, jelima i nagradama. Samo ako su tablice prazne.
    /// </summary>
    [HttpPost]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> RunSeed(CancellationToken cancellationToken)
    {
        if (await _db.Cities.AnyAsync(cancellationToken))
        {
            return Ok("Seed preskočen: baza već sadrži podatke.");
        }

        // Gradovi (BiH)
        var cities = new[]
        {
            new City { Name = "Sarajevo", PostalCode = "71000", Region = "Kanton Sarajevo", CreatedAt = DateTime.UtcNow, IsActive = true },
            new City { Name = "Banja Luka", PostalCode = "78000", Region = "Republika Srpska", CreatedAt = DateTime.UtcNow, IsActive = true },
            new City { Name = "Mostar", PostalCode = "88000", Region = "Hercegovačko-neretvanski kanton", CreatedAt = DateTime.UtcNow, IsActive = true },
            new City { Name = "Tuzla", PostalCode = "75000", Region = "Tuzlanski kanton", CreatedAt = DateTime.UtcNow, IsActive = true },
            new City { Name = "Zenica", PostalCode = "72000", Region = "Zeničko-dobojski kanton", CreatedAt = DateTime.UtcNow, IsActive = true },
            new City { Name = "Bihać", PostalCode = "77000", Region = "Unsko-sanski kanton", CreatedAt = DateTime.UtcNow, IsActive = true },
            new City { Name = "Brčko", PostalCode = "76100", Region = "Brčko distrikt", CreatedAt = DateTime.UtcNow, IsActive = true },
        };
        _db.Cities.AddRange(cities);
        await _db.SaveChangesAsync(cancellationToken);

        // Tipovi kuhinje (bosansko-srpski)
        var cuisineTypes = new[]
        {
            new CuisineType { Name = "Bosanska", Description = "Tradicionalna bosanska i balkanska kuhinja", IsActive = true },
            new CuisineType { Name = "Italijanska", Description = "Pizza, tjestenina, rizoto", IsActive = true },
            new CuisineType { Name = "Azijska", Description = "Kineska, japanska, tajlandska", IsActive = true },
            new CuisineType { Name = "Mediteranska", Description = "Morska hrana, maslinovo ulje", IsActive = true },
            new CuisineType { Name = "Američka", Description = "Burgeri, steak, roštilj", IsActive = true },
            new CuisineType { Name = "Meksička", Description = "Taco, burrito, nachos", IsActive = true },
            new CuisineType { Name = "Vegetarijanska", Description = "Biljna jela", IsActive = true },
            new CuisineType { Name = "Brza hrana", Description = "Sendviči, pizze, gril", IsActive = true },
        };
        _db.CuisineTypes.AddRange(cuisineTypes);
        await _db.SaveChangesAsync(cancellationToken);

        // Admin
        var (adminHash, adminSalt) = HashPassword(AdminPassword);
        var admin = new User
        {
            FirstName = "Admin",
            LastName = "Sustav",
            Email = "admin@rs2restobook.local",
            Username = "admin",
            PasswordHash = adminHash,
            PasswordSalt = Convert.ToBase64String(adminSalt),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            IsAdmin = true,
            IsClient = false,
        };
        _db.Users.Add(admin);
        await _db.SaveChangesAsync(cancellationToken);

        // Klijent (samo korisnik, ne vlasnik restorana)
        var (clientHash, clientSalt) = HashPassword(ClientPassword);
        var klijent = new User
        {
            FirstName = "Test",
            LastName = "Klijent",
            Email = "klijent@rs2restobook.local",
            Username = "klijent",
            PasswordHash = clientHash,
            PasswordSalt = Convert.ToBase64String(clientSalt),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            IsAdmin = false,
            IsClient = true,
        };
        _db.Users.Add(klijent);
        await _db.SaveChangesAsync(cancellationToken);

        var citiesList = await _db.Cities.OrderBy(c => c.Id).ToListAsync(cancellationToken);
        var cuisinesList = await _db.CuisineTypes.ToListAsync(cancellationToken);
        var cityByName = citiesList.ToDictionary(c => c.Name);
        var cuisineByName = cuisinesList.ToDictionary(c => c.Name);

        // 5 restorana (svi pripadaju adminu)
        var restaurantsData = new[]
        {
            new { CityName = "Sarajevo", CuisineName = "Bosanska", Name = "Kod Zece", Address = "Baščaršija 12", Phone = "+387 33 123 456", Email = "info@kodzece.ba", Desc = "Tradicionalna bosanska kuhinja u srcu Sarajeva.", Parking = true, Terrace = true, KidFriendly = true },
            new { CityName = "Banja Luka", CuisineName = "Italijanska", Name = "Bella Italia", Address = "Kralja Petra I 5", Phone = "+387 51 234 567", Email = "info@bellaitalia.ba", Desc = "Autentična italijanska kuhinja i pizza.", Parking = true, Terrace = false, KidFriendly = true },
            new { CityName = "Mostar", CuisineName = "Mediteranska", Name = "Stari most", Address = "Kujundžiluk 15", Phone = "+387 36 345 678", Email = "info@starimost.ba", Desc = "Mediteranska jela s pogledom na Stari most.", Parking = false, Terrace = true, KidFriendly = false },
            new { CityName = "Tuzla", CuisineName = "Brza hrana", Name = "Grill & Chill", Address = "Slatinska 8", Phone = "+387 35 456 789", Email = "info@grillchill.ba", Desc = "Burgeri, roštilj i brza hrana.", Parking = true, Terrace = true, KidFriendly = true },
            new { CityName = "Zenica", CuisineName = "Bosanska", Name = "Kod Ane", Address = "Kundurdžiluk 3", Phone = "+387 32 567 890", Email = "info@kodane.ba", Desc = "Domaća bosanska jela i ćevapi.", Parking = true, Terrace = false, KidFriendly = true },
        };

        foreach (var r in restaurantsData)
        {
            var restaurant = new Restaurant
            {
                OwnerId = admin.Id,
                Name = r.Name,
                Description = r.Desc,
                Address = r.Address,
                CityId = cityByName[r.CityName].Id,
                CuisineTypeId = cuisineByName[r.CuisineName].Id,
                PhoneNumber = r.Phone,
                Email = r.Email,
                HasParking = r.Parking,
                HasTerrace = r.Terrace,
                IsKidFriendly = r.KidFriendly,
                OpenTime = TimeSpan.FromHours(10),
                CloseTime = TimeSpan.FromHours(23),
                CreatedAt = DateTime.UtcNow,
                IsActive = true,
            };
            _db.Restaurants.Add(restaurant);
            await _db.SaveChangesAsync(cancellationToken);

            var tables = new[]
            {
                new Table { RestaurantId = restaurant.Id, TableNumber = "1", Capacity = 2, PositionX = 1, PositionY = 1, TableType = TableType.Circle, IsActive = true },
                new Table { RestaurantId = restaurant.Id, TableNumber = "2", Capacity = 4, PositionX = 2, PositionY = 2, TableType = TableType.Square, IsActive = true },
                new Table { RestaurantId = restaurant.Id, TableNumber = "3", Capacity = 6, PositionX = 3, PositionY = 3, TableType = TableType.Rectangle, IsActive = true },
            };
            _db.Tables.AddRange(tables);

            var menuItems = new[]
            {
                new MenuItem { RestaurantId = restaurant.Id, Name = "Čorba", Description = "Dnevna juha", Price = 20.00m, Category = MenuCategory.Soup, Allergens = Allergen.None, IsAvailable = true, CreatedAt = DateTime.UtcNow },
                new MenuItem { RestaurantId = restaurant.Id, Name = "Glavno jelo", Description = "Jelo dana s prilogom", Price = 65.00m, Category = MenuCategory.MainCourse, Allergens = Allergen.None, IsAvailable = true, CreatedAt = DateTime.UtcNow },
                new MenuItem { RestaurantId = restaurant.Id, Name = "Desert", Description = "Dnevni desert", Price = 35.00m, Category = MenuCategory.Dessert, Allergens = Allergen.None, IsAvailable = true, CreatedAt = DateTime.UtcNow },
                new MenuItem { RestaurantId = restaurant.Id, Name = "Kafa", Description = "Espresso ili s mlijekom", Price = 12.00m, Category = MenuCategory.Beverage, Allergens = Allergen.None, IsAvailable = true, CreatedAt = DateTime.UtcNow },
            };
            _db.MenuItems.AddRange(menuItems);

            var rewards = new[]
            {
                new Reward { RestaurantId = restaurant.Id, Title = "Besplatna kafa", Description = "Jedna kafa gratis nakon 5 rezervacija.", PointsRequired = 50, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Reward { RestaurantId = restaurant.Id, Title = "Popust 10%", Description = "10% popusta na račun.", PointsRequired = 100, IsActive = true, CreatedAt = DateTime.UtcNow },
                new Reward { RestaurantId = restaurant.Id, Title = "Besplatna desert", Description = "Desert uz glavno jelo.", PointsRequired = 150, IsActive = true, CreatedAt = DateTime.UtcNow },
            };
            _db.Rewards.AddRange(rewards);
            await _db.SaveChangesAsync(cancellationToken);
        }

        return Ok("Seed završen. Admin: admin / " + AdminPassword + " (vlasnik restorana). Klijent: klijent / " + ClientPassword + ". 5 restorana u BiH, svaki s nagradama.");
    }

    private static (string Hash, byte[] Salt) HashPassword(string password)
    {
        var salt = new byte[SaltSize];
        using (var rng = RandomNumberGenerator.Create())
            rng.GetBytes(salt);
        using (var pbkdf2 = new Rfc2898DeriveBytes(password, salt, Iterations))
        {
            var hash = Convert.ToBase64String(pbkdf2.GetBytes(KeySize));
            return (hash, salt);
        }
    }
}
