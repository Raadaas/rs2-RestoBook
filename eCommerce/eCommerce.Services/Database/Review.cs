using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class Review
    {
        [Key]
        public int Id { get; set; }
        
        public int ReservationId { get; set; }
        
        [ForeignKey("ReservationId")]
        public Reservation Reservation { get; set; } = null!;
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        public int Rating { get; set; }
        
        [MaxLength(1000)]
        public string? Comment { get; set; }
        
        public int? FoodQuality { get; set; }
        
        public int? ServiceQuality { get; set; }
        
        public int? AmbienceRating { get; set; }
        
        public int? ValueForMoney { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public bool IsVerified { get; set; } = false;
    }
}

