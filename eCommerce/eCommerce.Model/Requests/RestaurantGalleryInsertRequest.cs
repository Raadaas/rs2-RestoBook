using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class RestaurantGalleryInsertRequest
    {
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }

        [Required(ErrorMessage = "Image URL is required.")]
        [MaxLength(100000, ErrorMessage = "Image URL exceeds maximum length.")]
        public string ImageUrl { get; set; } = string.Empty;

        [MaxLength(20, ErrorMessage = "Image type must not exceed 20 characters.")]
        public string? ImageType { get; set; }

        public int DisplayOrder { get; set; } = 0;
    }
}
