using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        public int TableId { get; set; }
        
        [ForeignKey("TableId")]
        public Table Table { get; set; } = null!;
        
        public DateTime ReservationDate { get; set; }
        
        public TimeSpan ReservationTime { get; set; }
        
        public int NumberOfGuests { get; set; }
        
        [MaxLength(20)]
        public string Status { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? SpecialRequests { get; set; }
        
        [MaxLength(200)]
        public string? QRCode { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? ConfirmedAt { get; set; }
        
        public DateTime? CancelledAt { get; set; }
        
        [MaxLength(500)]
        public string? CancellationReason { get; set; }
        
        // Navigation properties
        public ICollection<ReservationHistory> History { get; set; } = new List<ReservationHistory>();
        public Review? Review { get; set; }
    }
}

