using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using eCommerce.Model;

namespace eCommerce.Model.Requests
{
    public class TableUpsertRequest
    {
        [Required(ErrorMessage = "Restaurant ID is required.")]
        public int RestaurantId { get; set; }
        
        [Required(ErrorMessage = "Table number is required.")]
        [MaxLength(20, ErrorMessage = "Table number must not exceed 20 characters.")]
        public string TableNumber { get; set; } = string.Empty;
        
        [Required(ErrorMessage = "Capacity is required.")]
        [Range(1, 50, ErrorMessage = "Capacity must be between 1 and 50.")]
        public int Capacity { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? PositionX { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? PositionY { get; set; }
        
        public TableType? TableType { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}

