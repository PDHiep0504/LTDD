using BE1.Models;
using BE1.Repositories;
using Microsoft.AspNetCore.Mvc;

[Route("api/[controller]")]
[ApiController]
public class ProductApiController : ControllerBase
{
	private readonly IProductRepository _productRepository;
	private readonly ILogger<ProductApiController> _logger;

	public ProductApiController(IProductRepository productRepository, ILogger<ProductApiController> logger)
	{
		_productRepository = productRepository;
		_logger = logger;
	}

	[HttpGet]
	public async Task<IActionResult> GetProducts()
	{
		try
		{
			var products = await _productRepository.GetProductsAsync();
			return Ok(products);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Failed to get products");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpGet("{id}")]
	public async Task<IActionResult> GetProductById(int id)
	{
		try
		{
			var product = await _productRepository.GetProductByIdAsync(id);
			if (product == null)
				return NotFound();
			return Ok(product);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Failed to get product by id {Id}", id);
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpPost]
	public async Task<IActionResult> AddProduct([FromBody] Product product)
	{
		try
		{
			await _productRepository.AddProductAsync(product);
			return CreatedAtAction(nameof(GetProductById), new { id = product.Id }, product);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Failed to add product");
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpPut("{id}")]
	public async Task<IActionResult> UpdateProduct(int id, [FromBody] Product product)
	{
		try
		{
			if (id != product.Id)
				return BadRequest();

			await _productRepository.UpdateProductAsync(product);
			return NoContent();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Failed to update product {Id}", id);
			return Problem("Internal server error", statusCode: 500);
		}
	}

	[HttpDelete("{id}")]
	public async Task<IActionResult> DeleteProduct(int id)
	{
		try
		{
			await _productRepository.DeleteProductAsync(id);
			return NoContent();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Failed to delete product {Id}", id);
			return Problem("Internal server error", statusCode: 500);
		}
	}
}