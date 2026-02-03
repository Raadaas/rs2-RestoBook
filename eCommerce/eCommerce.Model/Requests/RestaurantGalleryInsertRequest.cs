using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class RestaurantGalleryInsertRequest
    {
        [Required]
        public int RestaurantId { get; set; }

        [Required]
        [MaxLength(100000)]
        public string ImageUrl { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? ImageType { get; set; }

        public int DisplayOrder { get; set; } = 0;
    }
}
