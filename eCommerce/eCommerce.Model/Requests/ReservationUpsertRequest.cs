using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ReservationUpsertRequest
    {
        [Required(ErrorMessage = "User ID is required.")]
        public int UserId { get; set; }
        
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }
        
        [Required(ErrorMessage = "Please select a table.")]
        public int TableId { get; set; }
        
        [Required(ErrorMessage = "Reservation date is required.")]
        public DateTime ReservationDate { get; set; }
        
        [Required(ErrorMessage = "Reservation time is required.")]
        public TimeSpan ReservationTime { get; set; }
        
        [Required(ErrorMessage = "Duration is required.")]
        public TimeSpan Duration { get; set; } = TimeSpan.FromHours(2);
        
        [Required(ErrorMessage = "Number of guests is required.")]
        [Range(1, 50, ErrorMessage = "Number of guests must be between 1 and 50.")]
        public int NumberOfGuests { get; set; }
        
        [MaxLength(500, ErrorMessage = "Special requests must not exceed 500 characters.")]
        public string? SpecialRequests { get; set; }
        
        public DateTime? ConfirmedAt { get; set; }
        
        public DateTime? CancelledAt { get; set; }
        
        [MaxLength(500, ErrorMessage = "Cancellation reason must not exceed 500 characters.")]
        public string? CancellationReason { get; set; }
    }
}

