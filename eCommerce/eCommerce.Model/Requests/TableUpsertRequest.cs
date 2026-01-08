using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using eCommerce.Model;

namespace eCommerce.Model.Requests
{
    public class TableUpsertRequest
    {
        [Required]
        public int RestaurantId { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string TableNumber { get; set; } = string.Empty;
        
        [Required]
        public int Capacity { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? PositionX { get; set; }
        
        [Column(TypeName = "decimal(10,2)")]
        public decimal? PositionY { get; set; }
        
        public TableType? TableType { get; set; }
        
        public bool IsActive { get; set; } = true;
    }
}

