using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using SAS.Web.Data;
using SAS.Web.Models;

namespace SAS.Web.Pages;

public class IndexModel : PageModel
{
    private readonly AppDbContext _db;

    public IndexModel(AppDbContext db)
    {
        _db = db;
    }

    public List<Department> Departments { get; set; } = new();
    public DateOnly Today { get; set; } = DateOnly.FromDateTime(DateTime.Now);

    public async Task OnGetAsync()
    {
        Departments = await _db.Departments
            .Where(d => d.IsActive)
            .OrderBy(d => d.SortOrder)
            .Include(d => d.Areas.Where(a => a.IsActive).OrderBy(a => a.SortOrder))
            .Include(d => d.Shifts.Where(s => s.IsActive).OrderBy(s => s.SortOrder))
            .ToListAsync();
    }
}
