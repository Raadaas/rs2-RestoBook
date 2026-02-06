using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Model.Requests
{
    public class RestaurantUpsertRequest
    {
        [Required(ErrorMessage = "Owner ID is required.")]
        public int OwnerId { get; set; }
        
        [Required(ErrorMessage = "Restaurant name is required.")]
        [MaxLength(100, ErrorMessage = "Name must not exceed 100 characters.")]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(1000, ErrorMessage = "Description must not exceed 1000 characters.")]
        public string? Description { get; set; }
        
        [Required(ErrorMessage = "Address is required.")]
        [MaxLength(200, ErrorMessage = "Address must not exceed 200 characters.")]
        public string Address { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Please select a city.")]
        public int CityId { get; set; }
        
        [Column(TypeName = "decimal(9,6)")]
        public decimal? Latitude { get; set; }
        
        [Column(TypeName = "decimal(9,6)")]
        public decimal? Longitude { get; set; }
        
        [MaxLength(20, ErrorMessage = "Phone number must not exceed 20 characters.")]
        [RegularExpression(@"^[\+]?[0-9\s\-\(\)]{9,20}$", ErrorMessage = "Enter a valid phone number (e.g. +1 234 567 8900).")]
        public string? PhoneNumber { get; set; }
        
        [MaxLength(100, ErrorMessage = "Email must not exceed 100 characters.")]
        [EmailAddress(ErrorMessage = "Enter a valid email address (e.g. restaurant@domain.com).")]
        public string? Email { get; set; }
        
        [Required(ErrorMessage = "Please select a cuisine type.")]
        public int CuisineTypeId { get; set; }
        
        public bool HasParking { get; set; } = false;
        
        public bool HasTerrace { get; set; } = false;
        
        public bool IsKidFriendly { get; set; } = false;
        
        [Required(ErrorMessage = "Opening time is required.")]
        public TimeSpan OpenTime { get; set; }
        
        [Required(ErrorMessage = "Closing time is required.")]
        public TimeSpan CloseTime { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}

