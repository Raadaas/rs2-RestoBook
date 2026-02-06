using System;
using System.ComponentModel.DataAnnotations;

namespace eCommerce.Model.Requests
{
    public class ReservationHistoryUpsertRequest
    {
        [Required(ErrorMessage = "Reservation ID is required.")]
        public int ReservationId { get; set; }
        
        [MaxLength(20, ErrorMessage = "Previous status must not exceed 20 characters.")]
        public string? StatusChangedFrom { get; set; }
        
        [Required(ErrorMessage = "New status is required.")]
        [MaxLength(20, ErrorMessage = "Status must not exceed 20 characters.")]
        public string StatusChangedTo { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Changed by user ID is required.")]
        public int ChangedByUserId { get; set; }
        
        [MaxLength(500, ErrorMessage = "Notes must not exceed 500 characters.")]
        public string? Notes { get; set; }
    }
}

