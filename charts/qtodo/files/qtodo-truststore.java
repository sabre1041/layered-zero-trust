import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.security.KeyStore;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.util.Collection;

/**
 * Utility class for importing CA certificates from a PEM bundle into a PKCS12
 * truststore.
 */
public final class QtodoTruststore {
    /** Conversion factor from milliseconds to seconds. */
    private static final double MILLISECONDS_TO_SECONDS = 1000.0;

    private QtodoTruststore() {
        // Utility class - prevent instantiation
    }

    /**
     * Main entry point for the truststore import utility.
     *
     * @param args Command line arguments (not used)
     * @throws Exception if certificate import fails
     */
    public static void main(final String[] args) throws Exception {
        long startTime = System.currentTimeMillis();

        // Get environment variables
        String bundlePath = System.getenv("CA_BUNDLE");
        String p12Path = System.getenv("TRUSTSTORE_PATH");
        String password = System.getenv("TRUSTSTORE_PASSWORD");

        // Validate required environment variables
        boolean missingVars = false;
        if (bundlePath == null || bundlePath.isEmpty()) {
            System.err.println(
                "ERROR: CA_BUNDLE environment variable is not set");
            missingVars = true;
        }
        if (p12Path == null || p12Path.isEmpty()) {
            System.err.println(
                "ERROR: TRUSTSTORE_PATH environment variable is not set");
            missingVars = true;
        }
        if (password == null || password.isEmpty()) {
            System.err.println(
                "ERROR: TRUSTSTORE_PASSWORD environment variable "
                + "is not set");
            missingVars = true;
        }

        if (missingVars) {
            System.exit(1);
        }

        System.out.println("Converting CA bundle to PKCS12 truststore...");
        System.out.println("  CA bundle: " + bundlePath);
        System.out.println("  Output: " + p12Path);

        // Create empty PKCS12 keystore
        KeyStore keyStore = KeyStore.getInstance("PKCS12");
        keyStore.load(null, password.toCharArray());

        // Load certificates from PEM bundle
        CertificateFactory certFactory =
            CertificateFactory.getInstance("X.509");
        Collection<? extends Certificate> certs;

        try (InputStream fis = new FileInputStream(bundlePath)) {
            certs = certFactory.generateCertificates(fis);
        }

        // Import each certificate
        int count = 0;
        for (Certificate cert : certs) {
            String alias = "ztvp-ca-" + String.format("%03d", count);
            keyStore.setCertificateEntry(alias, cert);
            count++;
        }

        // Save the keystore
        try (FileOutputStream fos = new FileOutputStream(p12Path)) {
            keyStore.store(fos, password.toCharArray());
        }

        long elapsed = System.currentTimeMillis() - startTime;
        System.out.println("Successfully imported " + count
            + " certificates into PKCS12 truststore");
        System.out.println("Completed in "
            + (elapsed / MILLISECONDS_TO_SECONDS) + " seconds");
    }
}
