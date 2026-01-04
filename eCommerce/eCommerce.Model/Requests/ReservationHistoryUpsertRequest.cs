using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ReservationHistoryUpsertRequest
    {
        [Required]
        public int ReservationId { get; set; }
        
        [MaxLength(20)]
        public string? StatusChangedFrom { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string StatusChangedTo { get; set; } = string.Empty;
        
        [Required]
        public int ChangedByUserId { get; set; }
        
        [MaxLength(500)]
        public string? Notes { get; set; }
    }
}

