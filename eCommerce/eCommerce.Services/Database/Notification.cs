using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Services.Database
{
    public class Notification
    {
        [Key]
        public int Id { get; set; }
        
        public int UserId { get; set; }
        
        [ForeignKey("UserId")]
        public User User { get; set; } = null!;
        
        [MaxLength(50)]
        public string? Type { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;
        
        public int? RelatedReservationId { get; set; }
        
        [ForeignKey("RelatedReservationId")]
        public Reservation? RelatedReservation { get; set; }
        
        public bool IsRead { get; set; } = false;
        
        public DateTime SentAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? ReadAt { get; set; }
    }
}

