using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ReviewUpsertRequest
    {
        [Required(ErrorMessage = "Reservation ID is required.")]
        public int ReservationId { get; set; }
        
        [Required(ErrorMessage = "User ID is required.")]
        public int UserId { get; set; }
        
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }
        
        [Required(ErrorMessage = "Rating is required.")]
        [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")]
        public int Rating { get; set; }
        
        [MaxLength(1000, ErrorMessage = "Comment must not exceed 1000 characters.")]
        public string? Comment { get; set; }
        
        [Range(1, 5, ErrorMessage = "Food quality rating must be between 1 and 5.")]
        public int? FoodQuality { get; set; }
        
        [Range(1, 5, ErrorMessage = "Service quality rating must be between 1 and 5.")]
        public int? ServiceQuality { get; set; }
        
        [Range(1, 5, ErrorMessage = "Ambience rating must be between 1 and 5.")]
        public int? AmbienceRating { get; set; }
        
        [Range(1, 5, ErrorMessage = "Value for money rating must be between 1 and 5.")]
        public int? ValueForMoney { get; set; }
        
        public bool IsVerified { get; set; } = false;
    }
}

