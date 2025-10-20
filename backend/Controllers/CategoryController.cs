using BE1.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BE1.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CategoryController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public CategoryController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/Category
        [HttpGet]
        [Authorize]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
        {
            var categories = await _context.Categories
                .Include(c => c.Products)
                .OrderBy(c => c.Name)
                .ToListAsync();
            
            return Ok(categories);
        }

        // GET: api/Category/5
        [HttpGet("{id}")]
        [Authorize]
        public async Task<ActionResult<Category>> GetCategory(int id)
        {
            var category = await _context.Categories
                .Include(c => c.Products)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (category == null)
            {
                return NotFound(new { message = "Không tìm thấy danh mục" });
            }

            return Ok(category);
        }

        // POST: api/Category
        [HttpPost]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<Category>> CreateCategory([FromBody] Category category)
        {
            if (string.IsNullOrWhiteSpace(category.Name))
            {
                return BadRequest(new { message = "Tên danh mục không được để trống" });
            }

            // Check if category name already exists
            var exists = await _context.Categories
                .AnyAsync(c => c.Name.ToLower() == category.Name.ToLower());
            
            if (exists)
            {
                return BadRequest(new { message = "Tên danh mục đã tồn tại" });
            }

            category.CreatedAt = DateTime.UtcNow;
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetCategory), new { id = category.Id }, category);
        }

        // PUT: api/Category/5
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] Category category)
        {
            if (id != category.Id)
            {
                return BadRequest(new { message = "ID không khớp" });
            }

            if (string.IsNullOrWhiteSpace(category.Name))
            {
                return BadRequest(new { message = "Tên danh mục không được để trống" });
            }

            var existingCategory = await _context.Categories.FindAsync(id);
            if (existingCategory == null)
            {
                return NotFound(new { message = "Không tìm thấy danh mục" });
            }

            // Check if new name already exists (excluding current category)
            var nameExists = await _context.Categories
                .AnyAsync(c => c.Id != id && c.Name.ToLower() == category.Name.ToLower());
            
            if (nameExists)
            {
                return BadRequest(new { message = "Tên danh mục đã tồn tại" });
            }

            existingCategory.Name = category.Name;
            existingCategory.Description = category.Description;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await CategoryExists(id))
                {
                    return NotFound();
                }
                throw;
            }

            return NoContent();
        }

        // DELETE: api/Category/5
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.Categories
                .Include(c => c.Products)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (category == null)
            {
                return NotFound(new { message = "Không tìm thấy danh mục" });
            }

            // Products will have CategoryId set to NULL automatically due to DeleteBehavior.SetNull
            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private async Task<bool> CategoryExists(int id)
        {
            return await _context.Categories.AnyAsync(c => c.Id == id);
        }
    }
}
