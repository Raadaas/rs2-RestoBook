namespace eCommerce.Model.SearchObjects
{
    public class RestaurantSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? CityId { get; set; }
        public int? CuisineTypeId { get; set; }
        public int? OwnerId { get; set; }
        public int? PriceRange { get; set; }
        public bool? HasParking { get; set; }
        public bool? HasTerrace { get; set; }
        public bool? IsKidFriendly { get; set; }
        public bool? IsActive { get; set; }
    }
}

