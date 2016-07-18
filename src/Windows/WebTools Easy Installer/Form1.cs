using Microsoft.Win32;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.IO;
using System.Windows.Forms;
using System.Net;
using System.IO.Compression;

namespace WebTools_Easy_Installer
{
    public partial class Form1 : Form
    {
        const string GitHubLatestInformation = "https://api.github.com/repos/dagalufh/webtools.bundle/releases/latest";

        public Form1()
        {
            InitializeComponent();
            AddToLog("Application started.");
           
            // Lets start by checking if Plex Media Server is installed or not.
            // We do this by checking that the registry value for Plugin-Dir is existing.
            
            RegistryKey RegCU = Registry.CurrentUser;
            RegistryKey Plex = RegCU.OpenSubKey("Software\\Plex, Inc.\\Plex Media Server", false);

            AddToLog("Checking for Plex Media Server...");
            if (Plex != null)
            {
                AddToLog("Found Plex in registry (HKCU\\Software\\Plex, Inc.\\Plex Media Server).");
                string PlexPluginDir = Environment.GetEnvironmentVariable("LOCALAPPDATA") + "\\Plex Media Server\\Plug-ins";
                try
                {
                    PlexPluginDir = Plex.GetValue("LocalAppDataPath").ToString() + "\\Plex Media Server\\Plug-ins";
                    AddToLog("Found custom PluginDir. (" + PlexPluginDir + ")");
                } catch
                {
                    AddToLog("Using default PluginDir. (" + PlexPluginDir + ")");
                    // No custom path set. Using default.
                    //MessageBox.Show("Error occured while fetching registry value: " + e.Message);
                }

                TargetInstallDir.Text = PlexPluginDir;
                //MessageBox.Show("Target Plugin path: " + PlexPluginDir);


                // Check if WebTools is already installed.
                if (Directory.Exists(PlexPluginDir + "\\WebTools.Bundle") == true) {
                    AddToLog("Previous WebTools installation found.");

                    // Check what version is installed.
                    if (File.Exists(PlexPluginDir + "\\WebTools.Bundle\\VERSION") == true)
                    {
                        string[] lines = File.ReadAllLines(PlexPluginDir + "\\WebTools.Bundle\\VERSION");
                        foreach (string line in lines)
                        {
                            if (line.Length > 0)
                            {
                                label6.Text = line;
                                break;
                            }
                        }
                    }
                    // Checking if __init__.py contains VERSION = 
                    else if (File.Exists(PlexPluginDir + "\\WebTools.Bundle\\Contents\\Code\\__init__.py") == true)
                    {
                        string[] lines = File.ReadAllLines(PlexPluginDir + "\\WebTools.Bundle\\Contents\\Code\\__init__.py");
                        foreach (string line in lines)
                        {
                            if (line.IndexOf("VERSION = ") != -1)
                            {
                                char[] chars = { '=' };   
                                string[] version = line.Split(chars);
                                version[1] = version[1].ToString().Trim();

                                label6.Text = version[1].Substring(1,version[1].Length -2);

                                break;
                            }
                        }
                    } else
                    {
                        label6.Text = "-";
                        AddToLog("Unable to locate __init__.py or VERSION to determine installed version. Might be a corrupt installation.");
                    }
                    

                    

                } else
                {
                    AddToLog("No previous WebTools installation found.");
                    label6.Text = "No previous installation found.";
                }

                // Check what version is available from GitHub
                HttpWebRequest GitHubWebClient =(HttpWebRequest)HttpWebRequest.Create(GitHubLatestInformation);
                GitHubWebClient.Method = "GET";
                GitHubWebClient.UserAgent = "Custom";
                try
                {
                    // Fetch the information about the latest release from github
                    HttpWebResponse response = (HttpWebResponse)GitHubWebClient.GetResponse();
                    Stream dataStream = response.GetResponseStream();
                    StreamReader reader = new StreamReader(dataStream);
                    string TEST= reader.ReadToEnd();
                    reader.Close();
                    dataStream.Close();
                    
                    // Split on " since it's one long JSON string.
                    string[] lines = TEST.Split(new string[] { "\"" }, StringSplitOptions.None);
                    for (var i = 0; i < lines.Length; i++)
                    {

                        // Look for tag_name, this contains the version number
                        if (lines[i].IndexOf("tag_name") != -1)
                        {
                            label7.Text = lines[i + 2];
                        }

                        // Look for the download link to be used when downloading the plugin.
                        if ( (lines[i].IndexOf("browser_download_url") != -1) && (lines[i +2].IndexOf("WebTools.bundle.zip") != -1) )
                        {
                            linkLabel1.Text = lines[i + 2];
                        }
                        
                    }

                } catch (Exception e)
                {
                    MessageBox.Show("Error: " + e.Message);
                }
                
            }
            else
            {
                MessageBox.Show("Plex Media Server does not seem to be installed.");
                AddToLog("Plex Media server not found. Make sure it's installed first.");
                this.Close();
            }

        }

        // Unified logfunction
        private void AddToLog( string Message)
        {
            LogBox.AppendText(Message + Environment.NewLine);
        }

        private void button1_Click(object sender, EventArgs e)
        {
            // Installation function
            StatusBar.Visible = true;
            ProgressBar.Visible = true;
            ProgressBar.Value = 0;
            AddToLog("Starting Installation");
            string TemporaryFilename = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\WebTools.Bundle.Latest.zip";

            if (File.Exists(TemporaryFilename) == true) {
                AddToLog("Removing old installation zip.");
                File.Delete(TemporaryFilename);

            }
            
             try
            {
                StatusBar.Text = "";
                AddToLog("Starting download of: " + linkLabel1.Text);
                AddToLog("Temporary target: " + TemporaryFilename);

                WebClient wc = new WebClient();
                wc.Headers.Add("user-agent", "custom");
                wc.DownloadProgressChanged += wc_DownloadProgressChanged;
                wc.DownloadFileCompleted += Wc_DownloadFileCompleted;
                wc.DownloadFileAsync(new System.Uri(linkLabel1.Text), TemporaryFilename);
 
            } catch (Exception wce)
            {
                MessageBox.Show("Error: " + wce.Message);
            }

        }

        private void Wc_DownloadFileCompleted(object sender, AsyncCompletedEventArgs e)
        {
            StatusBar.Text = "";
            StatusBar.Visible = false;
            ProgressBar.Visible = false;
            AddToLog("Download completed.");
            UnPack();

        }

        void wc_DownloadProgressChanged(object sender, DownloadProgressChangedEventArgs e)
        {
            StatusBar.Text = "Downloading WebTools.Bundle.Zip: " + e.ProgressPercentage + " completed.";
            ProgressBar.Value = e.ProgressPercentage;
        }

        void UnPack()
        {
            if (Directory.Exists(TargetInstallDir.Text + "\\WebTools.Bundle") == true)
            {
                AddToLog("Will now delete previous WebTools installation folder: " + TargetInstallDir.Text + "\\WebTools.Bundle");

                try
                {
                    Directory.Delete(TargetInstallDir.Text + "\\WebTools.Bundle", true);
                    AddToLog("Successfully deleted old folder: " + TargetInstallDir.Text + "\\WebTools.Bundle");
                } catch
                {
                    AddToLog("Failed to delete old folder: " + TargetInstallDir.Text + "\\WebTools.Bundle");
                    AddToLog("Make sure it's not in use.");
                }
            }
            AddToLog("Starting unpacking.");
            ZipArchive archive = ZipFile.Open(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\WebTools.Bundle.Latest.zip", ZipArchiveMode.Read);
            try
            {
                archive.ExtractToDirectory(TargetInstallDir.Text);
                AddToLog("Unpacking completed.");
            } catch (Exception uc)
            {
                AddToLog("An error occured while unpacking: " + uc.Message);
            }

            // Close Zip-file, unlocking it for the thread to remove it.
            archive.Dispose();

            AddToLog("Deleting zip file: " + Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\WebTools.Bundle.Latest.zip");
            File.Delete(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location) + "\\WebTools.Bundle.Latest.zip");

            AddToLog("Installation Complete.");
            MessageBox.Show("Installation complete.");
        }  

       
    }
}