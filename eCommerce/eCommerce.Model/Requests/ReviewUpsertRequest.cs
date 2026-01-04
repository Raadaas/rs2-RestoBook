using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ReviewUpsertRequest
    {
        [Required]
        public int ReservationId { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        public int RestaurantId { get; set; }
        
        [Required]
        public int Rating { get; set; }
        
        [MaxLength(1000)]
        public string? Comment { get; set; }
        
        public int? FoodQuality { get; set; }
        
        public int? ServiceQuality { get; set; }
        
        public int? AmbienceRating { get; set; }
        
        public int? ValueForMoney { get; set; }
        
        public bool IsVerified { get; set; } = false;
    }
}

