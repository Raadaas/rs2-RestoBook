using System;

namespace eCommerce.Model.Responses
{
    public class RestaurantGalleryResponse
    {
        public int Id { get; set; }
        public int RestaurantId { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public string? ImageType { get; set; }
        public int DisplayOrder { get; set; }
        public DateTime UploadedAt { get; set; }
    }
}
