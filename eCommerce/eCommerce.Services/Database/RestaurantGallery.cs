using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class RestaurantGallery
    {
        [Key]
        public int Id { get; set; }
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        [Required]
        [MaxLength(100000)]
        public string ImageUrl { get; set; } = string.Empty;
        
        [MaxLength(20)]
        public string? ImageType { get; set; }
        
        public int DisplayOrder { get; set; } = 0;
        
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    }
}

