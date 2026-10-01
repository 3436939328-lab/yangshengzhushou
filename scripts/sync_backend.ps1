$srcRoot = "d:\yangshengzhushou\.work\backend\src"
$dstRoot = "D:\SpringBoot\SpringBootDemo\src"

$files = @(
    @{Path="main\java\org\example\springbootdemo\controller\FamilyController.java"},
    @{Path="main\java\org\example\springbootdemo\controller\ConsultationController.java"},
    @{Path="main\java\org\example\springbootdemo\controller\DoctorReviewController.java"},
    @{Path="main\java\org\example\springbootdemo\service\HealthDetailService.java"},
    @{Path="main\java\org\example\springbootdemo\service\ConsultationService.java"},
    @{Path="main\java\org\example\springbootdemo\service\DoctorReviewService.java"},
    @{Path="main\java\org\example\springbootdemo\service\DoctorProfileService.java"},
    @{Path="main\java\org\example\springbootdemo\bean\Consultation.java"},
    @{Path="main\java\org\example\springbootdemo\bean\DoctorReview.java"},
    @{Path="main\java\org\example\springbootdemo\bean\DoctorProfile.java"},
    @{Path="main\java\org\example\springbootdemo\dao\DoctorReviewDao.java"},
    @{Path="main\java\org\example\springbootdemo\dao\DoctorProfileDao.java"},
    @{Path="main\java\org\example\springbootdemo\config\DoctorReviewSchemaInitializer.java"},
    @{Path="main\java\org\example\springbootdemo\config\DoctorProfileSchemaInitializer.java"},
    @{Path="main\java\org\example\springbootdemo\config\DataInitializer.java"},
    @{Path="main\java\org\example\springbootdemo\config\WebMvcConfig.java"},
    @{Path="main\java\org\example\springbootdemo\auth\PermissionService.java"},
    @{Path="main\java\org\example\springbootdemo\rag\RagSuggestionService.java"},
    @{Path="test\java\org\example\springbootdemo\rag\RagSuggestionServiceTest.java"},
    @{Path="main\resources\org.example.springbootdemo\ConsultationDao.xml"},
    @{Path="main\resources\org.example.springbootdemo\DoctorReviewDao.xml"},
    @{Path="main\resources\org.example.springbootdemo\DoctorProfileDao.xml"}
)

foreach ($file in $files) {
    $relPath = $file.Path
    $srcPath = Join-Path $srcRoot $relPath
    $dstPath = Join-Path $dstRoot $relPath
    if (Test-Path $srcPath) {
        $dstDir = Split-Path $dstPath -Parent
        if (-not (Test-Path $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        Copy-Item $srcPath $dstPath -Force
        Write-Host "OK: $relPath"
    } else {
        Write-Host "SKIP (not found): $relPath"
    }
}

Write-Host "`nDone! Now restart the backend from IntelliJ IDEA."
