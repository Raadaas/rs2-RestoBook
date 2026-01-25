using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ReservationUpsertRequest
    {
        [Required]
        public int UserId { get; set; }
        
        [Required]
        public int RestaurantId { get; set; }
        
        [Required]
        public int TableId { get; set; }
        
        [Required]
        public DateTime ReservationDate { get; set; }
        
        [Required]
        public TimeSpan ReservationTime { get; set; }
        
        [Required]
        public TimeSpan Duration { get; set; } = TimeSpan.FromHours(2); // Default 2 hours
        
        [Required]
        public int NumberOfGuests { get; set; }
        
        // Note: Status property removed - State is managed via state machine methods (Confirm, Cancel, Complete)
        // New reservations default to Requested state
        
        [MaxLength(500)]
        public string? SpecialRequests { get; set; }
        
        [MaxLength(200)]
        public string? QRCode { get; set; }
        
        public DateTime? ConfirmedAt { get; set; }
        
        public DateTime? CancelledAt { get; set; }
        
        [MaxLength(500)]
        public string? CancellationReason { get; set; }
    }
}

