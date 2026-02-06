using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eCommerce.Model.Requests
{
    public class SpecialOfferUpsertRequest
    {
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }
        
        [Required(ErrorMessage = "Offer title is required.")]
        [MaxLength(100, ErrorMessage = "Title must not exceed 100 characters.")]
        public string Title { get; set; } = string.Empty;
        
        [MaxLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string? Description { get; set; }
        
        [Range(0, 999.99, ErrorMessage = "Price must be between 0 and 999.99.")]
        [Column(TypeName = "decimal(5,2)")]
        public decimal Price { get; set; }
        
        [Required(ErrorMessage = "Valid from date is required.")]
        public DateTime ValidFrom { get; set; }
        
        [Required(ErrorMessage = "Valid to date is required.")]
        public DateTime ValidTo { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}

