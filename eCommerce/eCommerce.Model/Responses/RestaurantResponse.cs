using System;

namespace eCommerce.Model.Responses
{
    public class RestaurantResponse
    {
        public int Id { get; set; }
        public int OwnerId { get; set; }
        public string OwnerName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string Address { get; set; } = string.Empty;
        public int CityId { get; set; }
        public string CityName { get; set; } = string.Empty;
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }
        public int CuisineTypeId { get; set; }
        public string CuisineTypeName { get; set; } = string.Empty;
        public int PriceRange { get; set; }
        public decimal? AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public bool HasParking { get; set; }
        public bool HasTerrace { get; set; }
        public bool IsKidFriendly { get; set; }
        public TimeSpan OpenTime { get; set; }
        public TimeSpan CloseTime { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
    }
}

