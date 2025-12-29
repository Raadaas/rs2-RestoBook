using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class PointsTransaction
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int LoyaltyPointId { get; set; }
        
        [ForeignKey("LoyaltyPointId")]
        public LoyaltyPoint LoyaltyPoint { get; set; } = null!;
        
        public int? ReservationId { get; set; }
        
        [ForeignKey("ReservationId")]
        public Reservation? Reservation { get; set; }
        
        public int Points { get; set; }
        
        [MaxLength(20)]
        public string TransactionType { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string Description { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

