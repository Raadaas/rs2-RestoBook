using System;

namespace eCommerce.Model.Responses
{
    public class ReviewResponse
    {
        public int Id { get; set; }
        public int ReservationId { get; set; }
        public int UserId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public int RestaurantId { get; set; }
        public string RestaurantName { get; set; } = string.Empty;
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public int? FoodQuality { get; set; }
        public int? ServiceQuality { get; set; }
        public int? AmbienceRating { get; set; }
        public int? ValueForMoney { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsVerified { get; set; }
    }
}

