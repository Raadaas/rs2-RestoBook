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
        public int NumberOfGuests { get; set; }
        
        [MaxLength(20)]
        public string Status { get; set; } = string.Empty;
        
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

