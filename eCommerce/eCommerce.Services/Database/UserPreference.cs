using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class UserPreference
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int CuisineTypeId { get; set; }
        
        [ForeignKey("CuisineTypeId")]
        public CuisineType CuisineType { get; set; } = null!;
        
        public int? PriceRangePreference { get; set; }
        
        public TimeSpan? PreferredDiningTime { get; set; }
        
        [MaxLength(500)]
        public string? SpecialRequirements { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

