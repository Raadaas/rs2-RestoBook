using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class UserBehavior
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int RestaurantId { get; set; }
        
        [ForeignKey("RestaurantId")]
        public Restaurant Restaurant { get; set; } = null!;
        
        [MaxLength(50)]
        public string? ActionType { get; set; }
        
        public DateTime ActionDate { get; set; } = DateTime.UtcNow;
        
        public TimeSpan? TimeOfDay { get; set; }
        
        public int? PartySize { get; set; }
    }
}

