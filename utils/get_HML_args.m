function a = get_HML_args()

    % HML model fitted parameters: Sub-005
    params = [1.63396775e-04 7.65404055e-01 7.60087705e+00 1.97234965e+01 7.65470593e-01 1.91084910e-02];
    
    a.syn = 4;
    a.time = 10;
    a.dt = 0.01;
    a.params = params;
    a.a = 10;
    a.joint_dim = 20; 

    % Initial sequence for manual curriculum
    a.manual_seq = [3, 4, 2, 1, 4, 3, 1, 4, 2, 3, 1, 2];
end