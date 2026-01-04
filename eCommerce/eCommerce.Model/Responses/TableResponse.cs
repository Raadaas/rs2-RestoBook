namespace eCommerce.Model.Responses
{
    public class TableResponse
    {
        public int Id { get; set; }
        public int RestaurantId { get; set; }
        public string RestaurantName { get; set; } = string.Empty;
        public string TableNumber { get; set; } = string.Empty;
        public int Capacity { get; set; }
        public decimal? PositionX { get; set; }
        public decimal? PositionY { get; set; }
        public string? TableType { get; set; }
        public bool IsActive { get; set; }
    }
}

