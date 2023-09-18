import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.hdds.conf.ConfigurationSource;
import org.apache.hadoop.hdds.conf.OzoneConfiguration;
import org.apache.hadoop.ozone.client.*;
import org.apache.hadoop.ozone.client.io.OzoneInputStream;
import org.apache.hadoop.ozone.client.io.OzoneOutputStream;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

public class SimpleTest {

  public static void main(String[] args) {

    try {
      String configPath = "/hadoop/app/ozone/etc/hadoop/ozone-site.xml";
      Configuration config = new Configuration();
      config.addResource(new Path(configPath));
      ConfigurationSource c = new OzoneConfiguration(config);
      
// Let us create a client
      OzoneClient ozClient = OzoneClientFactory.getRpcClient(c);
		
// Get a reference to the ObjectStore using the client
      ObjectStore oStore = ozClient.getObjectStore();

// Let us create a volume to store our game assets.
// This default arguments for creating that volume.
//      oStore.createVolume("vol1");

      OzoneVolume vol1 = oStore.getVolume("vol1");
// Let us create a bucket called bucket1.
 //     vol1.createBucket("bucket1");



      OzoneBucket bucket1 = oStore.getVolume("vol1").getBucket("bucket1");
      byte[] data = "M".getBytes();
      String keyName = UUID.randomUUID().toString();
      OzoneOutputStream out = bucket1.createKey(keyName, data.length + 1);
	  
	  OzoneClient ozClient2 = OzoneClientFactory.getRpcClient(c);
ObjectStore oStore2 = ozClient2.getObjectStore();
OzoneVolume vol12 = oStore.getVolume("vol2");
OzoneBucket bucket2 = oStore.getVolume("vol1").getBucket("bucket1");
OzoneOutputStream out2 = bucket2.createKey(keyName, data.length + 1);

      out.write(data);
	  out2.write(data);
 long start = System.currentTimeMillis();
    for (int i = 0; i < 50000; i++) {
        out = bucket1.createKey(UUID.randomUUID().toString(), 0);
		out2 = bucket1.createKey(UUID.randomUUID().toString(), 0);
//        out.write(data);
	out.close();
	out2.close();
    }

    System.out.println("It took " + String.valueOf(System.currentTimeMillis() - start) + " to create 50k keys");  
    //out.close();

/*      byte[] inData = new byte[(int)data.length];
      OzoneInputStream introStream = bucket1.readKey(keyName);
      introStream.read(inData);

      System.out.println("data is: " +   new String(inData, StandardCharsets.UTF_8));
// Close the stream when it is done.
      introStream.close();

      ozClient.close();
*/
    } catch(Exception e) {
    throw new RuntimeException("got exception" + e.getMessage());
  }}
}
