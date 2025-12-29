using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Services.Database
{
    public class CuisineType
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string? Description { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        // Navigation properties
        public ICollection<Restaurant> Restaurants { get; set; } = new List<Restaurant>();
        public ICollection<UserPreference> UserPreferences { get; set; } = new List<UserPreference>();
    }
}

