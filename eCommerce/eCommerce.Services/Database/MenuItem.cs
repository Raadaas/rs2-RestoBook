using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class MenuItem
    {
        [Key]
        public int Id { get; set; }
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal Price { get; set; }
        
        [MaxLength(50)]
        public string? Category { get; set; }
        
        public bool IsVegetarian { get; set; } = false;
        
        public bool IsVegan { get; set; } = false;
        
        [MaxLength(200)]
        public string? Allergens { get; set; }
        
        [MaxLength(500)]
        public string? ImageUrl { get; set; }
        
        public bool IsAvailable { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

