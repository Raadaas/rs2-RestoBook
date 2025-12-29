using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class LoyaltyPoint
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        public int CurrentPoints { get; set; } = 0;
        
        public int TotalPointsEarned { get; set; } = 0;
        
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
        
        // Navigation properties
        public ICollection<PointsTransaction> Transactions { get; set; } = new List<PointsTransaction>();
    }
}

