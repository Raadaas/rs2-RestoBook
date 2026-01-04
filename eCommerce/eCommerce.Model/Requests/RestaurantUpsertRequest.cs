using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Model.Requests
{
    public class RestaurantUpsertRequest
    {
        [Required]
        public int OwnerId { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(1000)]
        public string? Description { get; set; }
        
        [Required]
        [MaxLength(200)]
        public string Address { get; set; } = string.Empty;
        
        [Required]
        public int CityId { get; set; }
        
        [Column(TypeName = "decimal(9,6)")]
        public decimal? Latitude { get; set; }
        
        [Column(TypeName = "decimal(9,6)")]
        public decimal? Longitude { get; set; }
        
        [Phone]
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }
        
        [EmailAddress]
        [MaxLength(100)]
        public string? Email { get; set; }
        
        [Required]
        public int CuisineTypeId { get; set; }
        
        public int PriceRange { get; set; }
        
        public bool HasParking { get; set; } = false;
        
        public bool HasTerrace { get; set; } = false;
        
        public bool IsKidFriendly { get; set; } = false;
        
        public bool IsActive { get; set; } = true;
    }
}

