using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class ReservationHistory
    {
        [Key]
        public int Id { get; set; }
        
        public int ReservationId { get; set; }
        
        [ForeignKey("ReservationId")]
        public Reservation Reservation { get; set; } = null!;
        
        [MaxLength(20)]
        public string? StatusChangedFrom { get; set; }
        
        [MaxLength(20)]
        public string StatusChangedTo { get; set; } = string.Empty;
        
        public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
        
        public int ChangedByUserId { get; set; }
        
        [ForeignKey("ChangedByUserId")]
        public User ChangedByUser { get; set; } = null!;
        
        [MaxLength(500)]
        public string? Notes { get; set; }
    }
}

