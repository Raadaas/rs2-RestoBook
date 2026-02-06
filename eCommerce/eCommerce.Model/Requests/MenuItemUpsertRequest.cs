using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Model.Requests
{
    public class MenuItemUpsertRequest
    {
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }
        
        [Required(ErrorMessage = "Item name is required.")]
        [MaxLength(100, ErrorMessage = "Name must not exceed 100 characters.")]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string? Description { get; set; }
        
        [Required(ErrorMessage = "Price is required.")]
        [Range(0, 99999.99, ErrorMessage = "Price must be between 0 and 99999.99.")]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }
        
        public MenuCategory? Category { get; set; }
        
        public Allergen Allergens { get; set; } = Allergen.None;
        
        public string? ImageUrl { get; set; }
        
        public bool IsAvailable { get; set; } = true;
    }
}

