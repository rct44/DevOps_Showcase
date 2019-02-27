#!groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*;
import groovy.io.FileType

// GLOBAL VARIABLES
domain = Domain.global()
store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
String SSH_DIR = "/ssh_keys"


println ''
println '***** LOADING JENKINS CREDENTIALS SCRIPT *****'
def sshDir = new File(SSH_DIR)
if(sshDir.exists()){
  sshDir.eachFileMatch FileType.FILES, ~/.*(?<!\.pub)/, { File file ->
    println 'ADDING USER SSH KEYS: '+file.name
    store.addCredentials(domain, new BasicSSHUserPrivateKey(
      CredentialsScope.GLOBAL,
      file.name+"-ssh", // id
      file.name, // username
      new BasicSSHUserPrivateKey.FileOnMasterPrivateKeySource(file.path), // ssh-key
      "", // password
      "Automatically uploaded key for: "+file.name //desc
    ))
  }
}
store.addCredentials(domain, new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  "jenkins-password", // id
  "Jenkis Slave with Password Configuration", // desc
  "jenkins", // username
  "jenkins" // password
))

println '***** JENKINS CREDENTIALS SCRIPT COMPLETE *****'
println ''
