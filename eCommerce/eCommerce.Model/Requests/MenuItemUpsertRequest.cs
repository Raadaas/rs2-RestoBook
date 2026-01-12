using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Model.Requests
{
    public class MenuItemUpsertRequest
    {
        [Required]
        public int RestaurantId { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }
        
        public MenuCategory? Category { get; set; }
        
        public Allergen Allergens { get; set; } = Allergen.None;
        
        public string? ImageUrl { get; set; }
        
        public bool IsAvailable { get; set; } = true;
    }
}

