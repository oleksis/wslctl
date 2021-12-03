using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Application\AbstractController.psm1"
using module "..\Tools\ExtendedConsole.psm1"
using module "..\Service\BucketService.psm1"


Class BucketController : AbstractController
{

    [BucketService] $bucketService

    BucketController() : base()
    {
        $this.bucketService = [BucketService]([ServiceLocator]::getInstance().get('bucket'))
    }


    [void] add([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 2)
        $bucketName = $Arguments[0]
        $remoteUrl = $Arguments[1]

        if (-Not ($bucketName -imatch '^[a-z][a-z0-9]{4,20}$'))
        {
            throw "Invalid bucket name format (5 char min, 20 max, [a-z0-9]*)"
        }

        try { [System.Net.WebRequest]::Create($remoteUrl) }
        catch { throw "Invalid url '$remoteUrl'" }

        [ExtendedConsole]::WriteColor( "Adding Bucket $bucketName -> $remoteUrl", "Yellow")
        $this.bucketService.add($bucketName, $remoteUrl)
        $this.bucketService.commit()
    }

    [void] remove([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1)
        $bucketName = $Arguments[0]

        [ExtendedConsole]::WriteColor( "Removing Bucket", "Yellow")
        $this.bucketService.remove($bucketName)
        $this.bucketService.commit()
    }

    [void] list([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)
        [ExtendedConsole]::WriteColor( "Available buckets:", "Yellow")
        $this.bucketService.search("*") | ForEach-Object {
            # colorize output
            $name, $url = $_.Split(" ")
            [ExtendedConsole]::WriteColor( @($name, $url), @("Green", "White"))
        }
    }
}
