namespace BE1.Models;

public class Product
{
    public int Id { get; set; }
    public string? Name { get; set; }
    public decimal Price { get; set; }
    public string? Image { get; set; }
    public string? Description { get; set; }
    
    // Category relationship
    public int? CategoryId { get; set; }
    public Category? Category { get; set; }
}
